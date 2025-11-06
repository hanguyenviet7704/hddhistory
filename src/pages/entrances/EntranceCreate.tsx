import EntranceForm from "./EntranceForm";
import { useNavigate } from "react-router-dom";
import { ILesson } from "../../types/interface/lesson.interface";

export default function EntranceCreate() {
  const navigate = useNavigate();

  const handleSave = (entrance: ILesson) => {
    navigate(`/entrance/${entrance._id}`);
  };

  return <EntranceForm onSave={handleSave} />;
}
